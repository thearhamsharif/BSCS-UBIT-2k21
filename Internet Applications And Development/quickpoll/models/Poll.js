import mongoose from 'mongoose';

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
    type: Map,
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

const Poll = mongoose.model('Poll', pollSchema);

export default Poll;