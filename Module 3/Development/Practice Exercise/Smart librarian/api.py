"""
Smart Librarian Flask API Backend
Exposes REST endpoints for the book recommendation chatbot
"""

import os
import json
import chromadb
from dotenv import load_dotenv
from openai import OpenAI
from flask import Flask, request, jsonify
from flask_cors import CORS
from typing import List, Dict

load_dotenv()

# Initialize Flask app
app = Flask(__name__)
CORS(app)  # Enable CORS for all routes

# OpenAI client
client = OpenAI(api_key=os.getenv("OPENAI_API_KEY"))

# Configuration
CHROMA_PATH = "./chroma_db"
COLLECTION_NAME = "book_summaries"


def get_embedding(text: str):
    """Get embedding for text using OpenAI"""
    response = client.embeddings.create(
        model="text-embedding-3-small",
        input=text
    )
    return response.data[0].embedding


def get_collection():
    """Get or create Chroma collection"""
    chroma_client = chromadb.PersistentClient(path=CHROMA_PATH)
    return chroma_client.get_collection(name=COLLECTION_NAME)


def retrieve_books(user_query: str):
    """Retrieve relevant books based on user query"""
    collection = get_collection()
    query_embedding = get_embedding(user_query)

    results = collection.query(
        query_embeddings=[query_embedding],
        n_results=3
    )

    if not results["documents"] or not results["documents"][0]:
        return []

    retrieved_books = []

    for i, document in enumerate(results["documents"][0]):
        book_id = results["ids"][0][i] if results.get("ids") and results["ids"][0] else None

        retrieved_books.append({
            "id": book_id,
            "document": document
        })

    return retrieved_books


def is_abusive_query(text: str) -> bool:
    """Check if query contains abusive language"""
    response = client.chat.completions.create(
        model="gpt-4o-mini",
        temperature=0,
        messages=[
            {
                "role": "system",
                "content": (
                    "You are a classifier that decides whether a user query should be blocked "
                    "because it contains vulgar or insulting language used abusively. "
                    "Do not classify neutral or clinical references to sexual topics as abusive "
                    "unless the language is clearly vulgar or insulting."
                )
            },
            {
                "role": "user",
                "content": (
                    "Answer with exactly YES or NO.\n\n"
                    f"Query: {text}\n\n"
                    "Should this query be rejected because it uses vulgarity or insult language?"
                )
            }
        ]
    )

    answer = response.choices[0].message.content.strip().upper()
    return answer.startswith("YES")


def get_summary_by_title(title: str) -> str:
    """Get full summary for a book by exact title"""
    json_path = os.path.join(os.path.dirname(__file__), "data", "book_summaries.json")

    try:
        with open(json_path, "r", encoding="utf-8") as f:
            books = json.load(f)
    except FileNotFoundError:
        return "Summary file not found."
    except json.JSONDecodeError:
        return "Could not read summary data."

    for book in books:
        if book.get("title") == title:
            return book.get("summary", "No summary available for that title.")

    for book in books:
        if book.get("title", "").strip().lower() == title.strip().lower():
            return book.get("summary", "No summary available for that title.")

    return "No book with that exact title was found."


def generate_recommendation(user_query: str, retrieved_books: list):
    """Generate a book recommendation using GPT with function calling"""
    
    retrieved_context = "\n\n---\n\n".join(
        [
            f"Candidate {i+1}:\nID: {book['id']}\n{book['document']}"
            for i, book in enumerate(retrieved_books)
        ]
    )

    tools = [
        {
            "type": "function",
            "name": "get_summary_by_title",
            "description": "Return the full summary for an exact book title from the local database.",
            "parameters": {
                "type": "object",
                "properties": {
                    "title": {
                        "type": "string",
                        "description": "The exact title of the recommended book"
                    }
                },
                "required": ["title"],
                "additionalProperties": False
            },
            "strict": True
        }
    ]

    input_list = [
        {
            "role": "system",
            "content": (
                "You are a helpful AI librarian. "
                "Your task is to recommend a book based on the user's query. "
                "Follow these instructions carefully:\n"
                "1. Understand the user's request by meaning.\n"
                "2. If the user doesn't ask for a book recommendation, respond with: ""I can't help with that. Please ask for a book recommendation.""\n"
                "3. Review the retrieved books and choose the single best match for the user's request.\n"
                "4. Recommend a book only if it is a strong semantic match.\n"
                "5. Prefer books whose themes and summary explicitly overlap with the user's interests.\n"
                "6. Do not stretch the interpretation of a book to make it seem relevant if it is only loosely related.\n"
                "7. Keep the answer friendly, natural and concise.\n"
                "8. Mention the exact title of the recommended book.\n"
                "9. Do not justify weak or unrelated matches.\n"
                "10. Do not recommend any book that is not in the retrieved context.\n"
                "11. If no retrieved book is a good fit, say only: ""I couldn't find a book about this in the current database."" and do not recommend or mention any books outside the retrieved list.\n"
                "12. If any vulgarity or inappropriate content is detected, politely ask the user to rephrase.\n"
                "13. Do not include any summary or description in your initial response; only recommend the title.\n"
                "14. After recommending the title, call get_summary_by_title with the exact title to get the full summary.\n"
                "15. Never suggest titles that are not present in the retrieved books."
            )
        },
        {
            "role": "user",
            "content": (
                f"User Query:\n{user_query}\n\n"
                f"Retrieved Books:\n{retrieved_context}\n\n"
                "Based on the above, recommend a book to the user."
            )
        }
    ]

    response = client.responses.create(
        model="gpt-4o-mini",
        input=input_list,
        tools=tools,
        temperature=0.7
    )

    # Check for non-recommendation queries
    if response.output and response.output[0].type == "message" and response.output[0].content:
        text = response.output[0].content[0].text
        if "Please ask for a book recommendation" in text:
            return text

    input_list += response.output

    for item in response.output:
        if item.type == "function_call":
            if item.name == "get_summary_by_title":
                title = json.loads(item.arguments)["title"]
                summary = get_summary_by_title(title)

                input_list.append({
                    "type": "function_call_output",
                    "call_id": item.call_id,
                    "output": summary,
                })

    final_response = client.responses.create(
        model="gpt-4o-mini",
        instructions=(
            "Respond with a conversational recommendation followed by the detailed summary "
            "returned by the tool, with 2 newlines between the proposition of title and the summary. Be clear, friendly and concise."
        ),
        tools=tools,
        input=input_list,
        temperature=0.7
    )

    return final_response.output_text


# ============ API ENDPOINTS ============

@app.route("/api/health", methods=["GET"])
def health():
    """Health check endpoint"""
    return jsonify({
        "status": "healthy",
        "service": "Smart Librarian API"
    }), 200


@app.route("/api/recommend", methods=["POST"])
def recommend():
    """
    Main endpoint for book recommendations
    
    Request body:
    {
        "query": "user query text"
    }
    
    Response:
    {
        "success": true/false,
        "recommendation": "recommendation text",
        "message": "error message if applicable"
    }
    """
    try:
        data = request.get_json()
        
        if not data or "query" not in data:
            return jsonify({
                "success": False,
                "message": "Missing 'query' field in request body"
            }), 400
        
        user_query = data["query"].strip()
        
        if not user_query:
            return jsonify({
                "success": False,
                "message": "Query cannot be empty"
            }), 400
        
        # Check for abusive content
        if is_abusive_query(user_query):
            return jsonify({
                "success": True,
                "recommendation": (
                    "I am here to help you with books recommendations, but I noticed your message contains inappropriate "
                    "language. Could you please rephrase your question without such content?"
                )
            }), 200
        
        # Retrieve relevant books
        retrieved_books = retrieve_books(user_query)
        
        if not retrieved_books:
            return jsonify({
                "success": True,
                "recommendation": "I couldn't find a suitable recommendation in the vector store."
            }), 200
        
        # Generate recommendation
        recommendation = generate_recommendation(user_query, retrieved_books)
        
        return jsonify({
            "success": True,
            "recommendation": recommendation
        }), 200
    
    except Exception as e:
        print(f"Error in /recommend: {str(e)}")
        return jsonify({
            "success": False,
            "message": f"Server error: {str(e)}"
        }), 500


@app.route("/api/retrieve", methods=["POST"])
def retrieve():
    """
    Endpoint to retrieve raw books for a query
    
    Request body:
    {
        "query": "user query text"
    }
    
    Response:
    {
        "success": true/false,
        "books": [...],
        "message": "error message if applicable"
    }
    """
    try:
        data = request.get_json()
        
        if not data or "query" not in data:
            return jsonify({
                "success": False,
                "message": "Missing 'query' field in request body"
            }), 400
        
        user_query = data["query"].strip()
        
        if not user_query:
            return jsonify({
                "success": False,
                "message": "Query cannot be empty"
            }), 400
        
        books = retrieve_books(user_query)
        
        return jsonify({
            "success": True,
            "books": books,
            "count": len(books)
        }), 200
    
    except Exception as e:
        return jsonify({
            "success": False,
            "message": f"Server error: {str(e)}"
        }), 500


@app.route("/api/summary/<title>", methods=["GET"])
def get_summary(title):
    """
    Endpoint to get summary for a specific book title
    
    URL parameter: title (book title)
    
    Response:
    {
        "success": true/false,
        "title": "book title",
        "summary": "summary text"
    }
    """
    try:
        if not title:
            return jsonify({
                "success": False,
                "message": "Title parameter is required"
            }), 400
        
        summary = get_summary_by_title(title)
        
        return jsonify({
            "success": True,
            "title": title,
            "summary": summary
        }), 200
    
    except Exception as e:
        return jsonify({
            "success": False,
            "message": f"Server error: {str(e)}"
        }), 500


if __name__ == "__main__":
    app.run(debug=True, host="localhost", port=5000)
