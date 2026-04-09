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
├── build_vector_store.py      # Builds and updates the vector database
├── chatbot.py                 # Main chatbot logic for recommendations
├── dependencies.txt           # Python package requirements
├── data/
│   └── book_summaries.json    # Book data (titles, authors, themes, summaries)
└── chroma_db/                 # Vector database storage (created during setup)
```

## Prerequisites

- Python 3.8 or higher
- OpenAI API key
- Git (for version control)

## Installation

### Step 1: Clone the Repository

```bash
git clone <repository-url>
cd "Smart librarian"
```

### Step 2: Create a Virtual Environment (Recommended)

```bash
# On Windows
python -m venv venv
venv\Scripts\activate

# On macOS/Linux
python3 -m venv venv
source venv/bin/activate
```

### Step 3: Install Dependencies

```bash
pip install -r dependencies.txt
```

### Step 4: Set Up Environment Variables

Create a `.env` file in the project root directory:

```bash
# .env
OPENAI_API_KEY=your_openai_api_key_here
```

Replace `your_openai_api_key_here` with your actual OpenAI API key from [platform.openai.com](https://platform.openai.com/api-keys).

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

### Step 3: Running the Chatbot

```bash
python chatbot.py
```

## Usage

### Example Interaction

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

## Configuration

### OpenAI Models Used

- **Embeddings**: `text-embedding-3-small` - for semantic understanding
- **Chat**: `gpt-4o-mini` - for recommendations and content moderation

### Vector Database Settings

- **Path**: `./chroma_db/`
- **Collection**: `book_summaries`
- **Retrieval**: Top 3 most similar books per query

## Troubleshooting

### Issue: "OPENAI_API_KEY not found"
**Solution**: Ensure your `.env` file exists in the project root and contains your valid OpenAI API key.

### Issue: "Collection not found"
**Solution**: Run `python build_vector_store.py` first to create the vector database.

### Issue: "ModuleNotFoundError"
**Solution**: Reinstall dependencies with `pip install -r dependencies.txt`, ensuring your virtual environment is activated.

### Issue: Slow embeddings generation
**Solution**: This is normal during the first vector store build. Subsequent retrievals are much faster.
