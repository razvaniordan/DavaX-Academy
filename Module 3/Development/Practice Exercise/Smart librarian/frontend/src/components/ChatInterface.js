import React, { useState, useRef, useEffect } from 'react';
import axios from 'axios';
import Message from './Message';
import './ChatInterface.css';
import { FiSend, FiLoader } from 'react-icons/fi';

const API_BASE_URL = 'http://localhost:5000/api';

function ChatInterface() {
  const [messages, setMessages] = useState([
    {
      id: 1,
      text: "Hello! I'm your Smart Librarian. Ask me for book recommendations about any topic you're interested in!",
      sender: 'bot',
      timestamp: new Date()
    }
  ]);
  const [inputValue, setInputValue] = useState('');
  const [isLoading, setIsLoading] = useState(false);
  const [error, setError] = useState('');
  const messagesEndRef = useRef(null);

  const scrollToBottom = () => {
    messagesEndRef.current?.scrollIntoView({ behavior: 'smooth' });
  };

  useEffect(() => {
    scrollToBottom();
  }, [messages]);

  const sendMessage = async (e) => {
    e.preventDefault();
    
    if (!inputValue.trim()) {
      return;
    }

    // Add user message
    const userMessage = {
      id: messages.length + 1,
      text: inputValue,
      sender: 'user',
      timestamp: new Date()
    };

    setMessages(prev => [...prev, userMessage]);
    setInputValue('');
    setIsLoading(true);
    setError('');

    try {
      const response = await axios.post(`${API_BASE_URL}/recommend`, {
        query: inputValue
      });

      if (response.data.success) {
        const botMessage = {
          id: messages.length + 2,
          text: response.data.recommendation,
          sender: 'bot',
          timestamp: new Date()
        };
        setMessages(prev => [...prev, botMessage]);
      } else {
        setError(response.data.message || 'Error getting recommendation');
      }
    } catch (err) {
      console.error('Error:', err);
      setError(
        err.response?.data?.message || 
        'Failed to connect to the server. Make sure the backend is running on http://localhost:5000'
      );
    } finally {
      setIsLoading(false);
    }
  };

  return (
    <div className="chat-container">
      <div className="chat-header">
        <h1>📚 Smart Librarian</h1>
        <p>AI-Powered Book Recommendations</p>
      </div>

      <div className="chat-messages">
        {messages.map((message) => (
          <Message key={message.id} message={message} />
        ))}
        {isLoading && (
          <div className="message bot-message loading">
            <div className="message-content">
              <FiLoader className="spinner" />
              <span>Searching for the perfect book for you...</span>
            </div>
          </div>
        )}
        {error && (
          <div className="message bot-message error">
            <div className="message-content">
              <span>⚠️ {error}</span>
            </div>
          </div>
        )}
        <div ref={messagesEndRef} />
      </div>

      <div className="chat-input-wrapper">
        <form onSubmit={sendMessage} className="chat-input-form">
          <input
            type="text"
            value={inputValue}
            onChange={(e) => setInputValue(e.target.value)}
            placeholder="Ask for a book recommendation..."
            className="chat-input"
            disabled={isLoading}
          />
          <button 
            type="submit" 
            className="send-button"
            disabled={isLoading || !inputValue.trim()}
          >
            <FiSend size={20} />
          </button>
        </form>
        <p className="hint">💡 Tip: Ask about topics, genres, or themes you're interested in!</p>
      </div>
    </div>
  );
}

export default ChatInterface;
