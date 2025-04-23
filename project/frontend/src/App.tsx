import React, { useEffect, useRef } from 'react';
import { ChatMessage } from './components/ChatMessage';
import { ChatInput } from './components/ChatInput';
import { TypingIndicator } from './components/TypingIndicator';
import { useChatStore } from './store/chatStore';
import { MessageSquare } from 'lucide-react';

// Simulated bot responses
const botResponses = [
  "Hello! How can I assist you today?",
  "That's an interesting question. Let me help you with that.",
  "I understand your concern. Here's what you can do...",
  "Could you please provide more details about your question?",
  "I'm here to help! What would you like to know?",
];

function App() {
  const { messages, addMessage, isTyping, setIsTyping } = useChatStore();
  const messagesEndRef = useRef<HTMLDivElement>(null);

  const scrollToBottom = () => {
    messagesEndRef.current?.scrollIntoView({ behavior: 'smooth' });
  };

  useEffect(() => {
    scrollToBottom();
  }, [messages]);

  const handleSendMessage = async (content: string) => {
    addMessage(content, 'user');
    setIsTyping(true);

    // Simulate API delay
    setTimeout(() => {
      const randomResponse = botResponses[Math.floor(Math.random() * botResponses.length)];
      addMessage(randomResponse, 'bot');
      setIsTyping(false);
    }, 1500);
  };

  return (
    <div className="min-h-screen bg-gray-50">
      <div className="max-w-4xl mx-auto p-4">
        {/* Header */}
        <div className="bg-white rounded-t-xl p-4 border-b">
          <div className="flex items-center gap-3">
            <div className="w-10 h-10 rounded-full bg-blue-500 flex items-center justify-center">
              <MessageSquare className="w-6 h-6 text-white" />
            </div>
            <div>
              <h1 className="text-xl font-bold text-gray-800">AI Chat Assistant</h1>
              <p className="text-sm text-gray-500">Ask me anything!</p>
            </div>
          </div>
        </div>

        {/* Chat Messages */}
        <div className="bg-white h-[600px] overflow-y-auto border-x">
          <div className="space-y-4 p-4">
            {messages.map((message) => (
              <ChatMessage key={message.id} message={message} />
            ))}
            {isTyping && <TypingIndicator />}
            <div ref={messagesEndRef} />
          </div>
        </div>

        {/* Input Area */}
        <div className="bg-white rounded-b-xl p-4 border">
          <ChatInput onSend={handleSendMessage} disabled={isTyping} />
        </div>
      </div>
    </div>
  );
}

export default App;