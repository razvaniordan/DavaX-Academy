# Smart Librarian

An AI-powered book recommendation chatbot that uses **RAG (Retrieval-Augmented Generation)**, semantic search and OpenAI language models to provide personalized book recommendations based on user queries.

## Overview

Smart Librarian is an intelligent system that matches user interests with relevant books from a curated database. It uses **vector embeddings** and a **ChromaDB vector store** to retrieve the most semantically relevant book candidates, then uses an OpenAI model to generate a natural-language recommendation based on the retrieved context. In addition, it can enrich the recommendation with a more detailed summary through function calling.

### Key Features

- **RAG-Based Recommendation Flow**: Combines retrieval from a vector database with LLM-generated responses
- **Semantic Book Matching**: Uses OpenAI embeddings to understand queries and match them with relevant books
- **Vector Database**: Stores book embeddings in ChromaDB for efficient retrieval
- **Content Moderation**: Filters abusive or inappropriate queries before processing
- **AI-Powered Recommendations**: Leverages GPT-4o-mini to generate personalized recommendations with explanations
- **Function Calling for Detailed Summaries**: Automatically retrieves an exact book summary after selecting the best recommendation

## Project Structure

```
Smart Librarian/
├── api.py                          # Flask API backend
├── chatbot.py                      # Original CLI version (kept for reference)
├── build_vector_store.py           # Vector store builder
├── dependencies.txt                # Python dependencies
├── .env                            # Environment variables (API keys, etc.)
├── data/
│   └── book_summaries.json         # Book data
├── chroma_db/                      # Vector database storage (it is created after running build_vector_store.py)
└── frontend/                       # React frontend
    ├── package.json
    ├── public/
    │   └── index.html
    └── src/
        ├── index.js
        ├── index.css
        ├── App.js
        ├── App.css
        └── components/
            ├── ChatInterface.js
            ├── ChatInterface.css
            ├── Message.js
            └── Message.css
```

## Prerequisites

- **Python 3.8+** - For the backend
- **Node.js 14+ and npm** - For the frontend
- **OpenAI API Key** - Required for model interactions

## Building the Vector Store

Before running the chatbot, you need to build the vector database with your book data.

### Step 1: Prepare Book Data

Ensure your `data/book_summaries.json` contains books in the following format:

```json
[
  {
    "title": "The Great Gatsby",
    "author": "F. Scott Fitzgerald",
    "themes": ["romance", "American Dream", "1920s"],
    "summary": "A classic novel about love and aspiration in the Jazz Age..."
  },
  {
    "title": "To Kill a Mockingbird",
    "author": "Harper Lee",
    "themes": ["justice", "childhood", "racism"],
    "summary": "A gripping tale of racial injustice and moral growth in the American South..."
  }
]
```

### Step 2: Build the Vector Store

```bash
python build_vector_store.py
```

This script will:
- Read all books from `data/book_summaries.json`
- Create vector embeddings for each book
- Store embeddings in the ChromaDB database (`./chroma_db/`)
- Detect and handle updates to existing books if you updated `data/book_summaries.json` file

## Setup Instructions

### 1. Backend Setup

#### Step 1a: Install Python Dependencies
```bash
pip install -r dependencies.txt
```

#### Step 1b: Set up Environment Variables
Create a `.env` file in the project root directory:
```
OPENAI_API_KEY=your_openai_api_key_here
```
Replace `your_openai_api_key_here` with your actual OpenAI API key from [platform.openai.com](https://platform.openai.com/api-keys).

### 2. Frontend Setup

#### Step 2a: Navigate to Frontend Directory
```bash
cd frontend
```

#### Step 2b: Install Node Dependencies
```bash
npm install
```

## Running the Application

### Run in Two Separate Terminals

**Terminal 1 - Start the Backend API:**
```bash
# From the project root directory
python api.py
```
The backend will start at `http://localhost:5000`

**Terminal 2 - Start the Frontend:**
```bash
# From the frontend directory
cd frontend
npm start
```
The frontend will automatically open at `http://localhost:3000`

## Usage

1. Start the backend API (it will run on `http://localhost:5000`)
2. Start the frontend (it will run on `http://localhost:3000`)
3. Open your browser to `http://localhost:3000`
4. Ask for book recommendations in natural language
5. The AI librarian will search through the book database and provide personalized recommendations

### Example Interaction with CLI

#### Running the Chatbot

```bash
python chatbot.py
```

The user will interact with the chatbot in CLI.

```
Smart Librarian CLI
Ask for a book recommendation.
Type 'exit' to quit.

You: Recommend me a book about war

Assistant: I recommend **All Quiet on the Western Front** by Erich Maria Remarque.

This anti-war novel follows a group of young German soldiers who enter World War I with patriotic illusions, only to discover the terror, exhaustion, and dehumanization of life at the front. Through the eyes of Paul Bäumer, the reader witnesses the physical destruction of battle and the psychological damage it leaves behind. The bonds of friendship among the soldiers offer moments of solidarity, but cannot shield them from fear, trauma, and the gradual loss of innocence. The novel is a powerful condemnation of war and a deeply human portrait of suffering, survival, and the emptiness behind heroic slogans.

You: exit
Assistant: Goodbye!
```

## What's Running Where

- **Backend API:** http://localhost:5000
- **Frontend Application:** http://localhost:3000
- **API Health Check:** http://localhost:5000/api/health

You can test the API directly in your browser by visiting `http://localhost:5000/api/health`

### Key Functions

- **`retrieve_books(user_query)`**: Finds the 3 most relevant books based on semantic similarity
- **`generate_recommendation(user_query, retrieved_books)`**: Generates a personalized recommendation with summary
- **`get_embedding(text)`**: Creates vector embeddings for any text
- **`is_abusive_query(text)`**: Checks if a query contains inappropriate content
- **`get_summary_by_title(title)`**: Retrieves the full summary for a specific book

## Dependencies

| Package | Purpose |
|---------|---------|
| `openai` | OpenAI API access (embeddings & chat models) |
| `chromadb` | Vector database for storing book embeddings |
| `python-dotenv` | Environment variable management |
| `tiktoken` | Token counting for OpenAI API |
| `flask` | Backend web framework for exposing the recommendation API |
| `flask-cors` | Enables Cross-Origin Resource Sharing so the React frontend can communicate with the Flask backend |

## Configuration

### OpenAI Models Used

- **Embeddings**: `text-embedding-3-small` - for semantic understanding
- **Chat**: `gpt-4o-mini` - for recommendations and content moderation

### Vector Database Settings

- **Path**: `./chroma_db/`
- **Collection**: `book_summaries`
- **Retrieval**: Top 3 most similar books per query

## Troubleshooting

### "Cannot connect to backend"
- Make sure the backend API is running with `python api.py`
- Check that the API is accessible at `http://localhost:5000`
- Verify CORS is enabled (it should be in api.py)

### "OPENAI_API_KEY not found"
- Create a `.env` file in the project root
- Add your OpenAI API key: `OPENAI_API_KEY=sk-...`
- Restart the backend

### "Vector store not found"
- Make sure you've run `python build_vector_store.py` first
- Check that the `chroma_db` folder exists

### "Frontend won't start"
- Make sure you're in the `frontend` directory: `cd frontend`
- Delete `node_modules` and run `npm install` again
- Make sure Node.js 14+ is installed: `node --version`

### "Port 5000 or 3000 already in use"
- Check what's using the port and close it
- Or modify the port in `api.py` (change `port=5000`) or `frontend/package.json`

## Development Notes

### Backend (Python)
- The `api.py` file contains the Flask server with all API endpoints
- The original `chatbot.py` is kept as a CLI reference implementation
- Modify `api.py` to add new endpoints or change behavior

### Frontend (React)
- Main logic is in `frontend/src/components/ChatInterface.js`
- Styling uses CSS modules for component isolation
- Axios is used for HTTP requests to the backend
- The UI uses React Icons for icons
