import React from 'react';
import { Bot, User } from 'lucide-react';
import { Message } from '../types/chat';
import { twMerge } from 'tailwind-merge';

interface ChatMessageProps {
  message: Message;
}

export const ChatMessage: React.FC<ChatMessageProps> = ({ message }) => {
  const isBot = message.sender === 'bot';

  return (
    <div
      className={twMerge(
        'flex gap-3 p-4 rounded-lg',
        isBot ? 'bg-gray-100' : 'bg-blue-50'
      )}
    >
      <div className="flex-shrink-0">
        <div className={twMerge(
          'w-8 h-8 rounded-full flex items-center justify-center',
          isBot ? 'bg-purple-500' : 'bg-blue-500'
        )}>
          {isBot ? (
            <Bot className="w-5 h-5 text-white" />
          ) : (
            <User className="w-5 h-5 text-white" />
          )}
        </div>
      </div>
      <div className="flex-1">
        <div className="font-medium text-sm text-gray-600 mb-1">
          {isBot ? 'AI Assistant' : 'You'}
        </div>
        <div className="text-gray-800">{message.content}</div>
      </div>
      <div className="text-xs text-gray-400 self-end">
        {new Date(message.timestamp).toLocaleTimeString([], { 
          hour: '2-digit', 
          minute: '2-digit' 
        })}
      </div>
    </div>
  );
};