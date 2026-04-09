import os
import json
import chromadb
from dotenv import load_dotenv
from openai import OpenAI

load_dotenv()

client = OpenAI(api_key=os.getenv("OPENAI_API_KEY"))

CHROMA_PATH = "./chroma_db"
COLLECTION_NAME = "book_summaries"


def get_embedding(text: str):
    response = client.embeddings.create(
        model="text-embedding-3-small",
        input=text
    )
    return response.data[0].embedding


def get_collection():
    chroma_client = chromadb.PersistentClient(path=CHROMA_PATH)
    return chroma_client.get_collection(name=COLLECTION_NAME)

def retrieve_books(user_query: str):
    collection = get_collection()
    query_embedding = get_embedding(user_query)

    results = collection.query(
        query_embeddings=[query_embedding],
        n_results=3
    )

    # print(results["ids"])
    # print(results["documents"])

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

    # check if the response is the fallback message for non-recommendation queries before processing function calls
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
            "returned by the tool. Be clear, friendly and concise."
        ),
        tools=tools,
        input=input_list,
        temperature=0.7
    )

    #print(input_list)
    return final_response.output_text


def main():
    print("Smart Librarian CLI")
    print("Ask for a book recommendation.")
    print("Type 'exit' to quit.\n")

    while True:
        user_query = input("You: ").strip()

        if user_query.lower() in ["exit", "quit"]:
            print("Assistant: Goodbye!")
            break

        if not user_query:
            print("Assistant: Please enter a question.\n")
            continue

        if is_abusive_query(user_query):
            print(
                "Assistant: I appreciate your interest, but I noticed your message contains inappropriate "
                "language. Could you please rephrase your question without such content?"
            )
            continue

        retrieved_books = retrieve_books(user_query)

        if not retrieved_books:
            print("Assistant: I couldn't find a suitable recommendation in the vector store.\n")
            continue

        recommendation = generate_recommendation(user_query, retrieved_books)
        print(f"\nAssistant: {recommendation}\n")


if __name__ == "__main__":
    main()
