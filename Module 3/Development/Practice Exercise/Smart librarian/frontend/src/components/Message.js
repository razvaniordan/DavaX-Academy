import React from 'react';
import './Message.css';

function Message({ message }) {
  const formatTime = (date) => {
    return date.toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' });
  };

  return (
    <div className={`message ${message.sender}-message`}>
      <div className="message-content">
        {message.text}
      </div>
      <span className="message-time">{formatTime(message.timestamp)}</span>
    </div>
  );
}

export default Message;
