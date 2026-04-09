import os
import json
import chromadb
from dotenv import load_dotenv
from openai import OpenAI

load_dotenv()

client = OpenAI(api_key=os.getenv("OPENAI_API_KEY"))

CHROMA_PATH = "./chroma_db"
BOOKS_FILE = "./data/book_summaries.json"
COLLECTION_NAME = "book_summaries"


def get_embedding(text: str):
    response = client.embeddings.create(
        model="text-embedding-3-small",
        input=text
    )
    return response.data[0].embedding


def build_book_id(book: dict) -> str:
    # building an unique id for the book using title and author
    return f"{book['title']}::{book['author']}"


def build_combined_text(book: dict) -> str:
    # the text based on which to create the embedding
    return (
        f"Title: {book['title']}\n"
        f"Author: {book['author']}\n"
        f"Themes: {', '.join(book['themes'])}\n"
        f"Summary: {book['summary']}"
    )


def main():
    with open(BOOKS_FILE, "r", encoding="utf-8") as f:
        books = json.load(f)

    chroma_client = chromadb.PersistentClient(path=CHROMA_PATH)

    collection = chroma_client.get_or_create_collection(name=COLLECTION_NAME)

    existing_data = collection.get(include=["documents"])
    existing_ids = existing_data["ids"]

    # creating a dictionary of existing documents by id
    # documents - the combined text used for embedding
    existing_docs_by_id = {}
    for i, book_id in enumerate(existing_ids):
        existing_docs_by_id[book_id] = {
            "document": existing_data["documents"][i]
        }

    # prepare sets and dicts for json books
    json_ids = set() # set to store ids of books from json for comparison
    books_by_id = {} # dict to store each book by its id for easy access during updates

    for book in books:
        bk_id = build_book_id(book)
        json_ids.add(bk_id)
        books_by_id[bk_id] = book

    # convert existing ids to set for comparison
    existing_ids_set = set(existing_ids)

    # determine ids to add, delete or update
    ids_to_add = json_ids - existing_ids_set
    ids_to_delete = existing_ids_set - json_ids
    ids_possible_update = json_ids & existing_ids_set

    # add new books to the collection
    for bk_id in ids_to_add:
        book = books_by_id[bk_id]
        combined_text = build_combined_text(book)
        embedding = get_embedding(combined_text)

        collection.add(
            ids=[bk_id],
            embeddings=[embedding],
            documents=[combined_text]
        )
        print(f"Added: {bk_id}")

    # check for updates in existing books
    for bk_id in ids_possible_update:
        book = books_by_id[bk_id]
        combined_text = build_combined_text(book)

        existing_document = existing_docs_by_id[bk_id]["document"]

        if combined_text != existing_document:
            embedding = get_embedding(combined_text)

            collection.update(
                ids=[bk_id],
                embeddings=[embedding],
                documents=[combined_text]
            )
            print(f"Updated: {bk_id}")

    # delete books that are no longer in the JSON
    if ids_to_delete:
        collection.delete(ids=list(ids_to_delete))
        for bk_id in ids_to_delete:
            print(f"Deleted: {bk_id}")

    # print completion message
    print("Collection sync complete.")


if __name__ == "__main__":
    main()