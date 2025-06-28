// Imports
import mongoose from 'mongoose';

// Define schema
const pollSchema = new mongoose.Schema({
  question: {
    type: String,
    required: true,
  },
  options: {
    type: [String],
    required: true,
  },
  votes: {
    type: Object,
    of: Number,
    default: {},
  },
  votedIPs: [String],
  creatorIP: {
    type: String,
    required: true,
  },
  status: {
    type: String,
    enum: ['Active', 'Closed'],
    default: 'Active',
  },
}, { timestamps: true });

// Define model
const Poll = mongoose.model('Poll', pollSchema);

// Export poll
export default Poll;