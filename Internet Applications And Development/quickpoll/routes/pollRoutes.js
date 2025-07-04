// Imports
import express from 'express';
import Poll from '../models/Poll.js';

// Create a new router
const router = express.Router();

// Get IP address of the client
const getIp = (req) => req.headers['x-forwarded-for'] || req.socket.remoteAddress;

// Index poll route
router.get('/', async (req, res) => {
  try {
    const polls = await Poll.find().sort({ createdAt: -1 });
    res.render('index', { polls });
  } catch (error) {
    console.error('Error fetching polls:', error);
    res.status(500).send('Internal Server Error');
  }
});

// Create poll route
router.get('/create', (req, res) => {
  res.render('create');
});

// Create post Route
router.post('/polls', async (req, res) => {
  const { question, options } = req.body;

  // Get IP
  const ip = getIp(req);

  // Validations
  if (typeof question !== 'string' || !Array.isArray(options)) {
    return res.status(400).send('Invalid input: question must be a string and options must be an array');
  }

  // Check unique poll
  const cleanedOptions = options
    .map(opt => opt.trim())
    .filter((opt, index, self) => {
      const lowerCaseOpt = opt.toLowerCase();

      if (opt === '') {
        return false;
      }

      return self.map(item => item.toLowerCase()).indexOf(lowerCaseOpt) === index;
    });

  // Unique poll validation
  if (cleanedOptions.length < 3) {
    return res.status(400).render('create', {
      error: 'All unique options are required.',
      old: { question, options }
    });
  }

  // Options validation
  const votes = {};
  cleanedOptions.forEach(opt => {
    if (typeof opt === 'string') {
      votes[opt] = 0;
    } else {
      return res.status(400).send('Invalid input: all options must be strings');
    }
  });

  // Set poll
  const poll = new Poll({ question, options: cleanedOptions, votes, votedIPs: [], creatorIP: ip });

  try {
    await poll.save();
    res.redirect(`/polls/${poll._id}`);
  } catch (error) {
    console.error('Error saving poll:', error);
    res.status(500).send('Internal Server Error');
  }
});

// Get poll route
router.get('/polls/:id', async (req, res) => {
  // Get IP
  const ip = getIp(req);

  try {
    const poll = await Poll.findById(req.params.id);

    // Validation
    if (!poll) {
      return res.status(404).send('Poll not found');
    }

    const hasVoted = poll.votedIPs.includes(ip);
    const isCreator = poll.creatorIP === ip;
    const votes = poll.votes || {};

    // Check winners
    const voteCounts = Object.values(votes).map(v => Number(v) || 0);
    const maxVotes = voteCounts.length ? Math.max(...voteCounts) : 0;
    const winners = Object.entries(votes)
      .filter(([_, count]) => Number(count) === maxVotes)
      .map(([option]) => option);
    const isTie = winners.length > 1;

    const optionVotes = poll.options.map(opt => ({
      name: opt,
      votes: Number(votes[opt]) || 0,
      isWinner: winners.includes(opt)
    }));

    res.render('poll', { poll, optionVotes, hasVoted, isCreator, isTie, winners });
  } catch (error) {
    console.error('Error fetching poll:', error);
    res.status(500).send('Internal Server Error');
  }
});

// Vote route
router.post('/polls/:id/vote', async (req, res) => {
  const { option } = req.body;

  // Get IP
  const ip = getIp(req);

  try {
    const poll = await Poll.findById(req.params.id);

    // Validations
    if (!poll || poll.status === 'Closed') return res.send('Poll is closed or not found.');
    if (poll.votedIPs.includes(ip)) return res.send('You have already voted.');

    if (!poll.options.includes(option)) return res.send('Invalid option.');

    // Add vote
    poll.votes[option] = (poll.votes[option] || 0) + 1;
    poll.markModified('votes');
    poll.votedIPs.push(ip);

    await poll.save();
    res.redirect(`/polls/${poll._id}`);
  } catch (error) {
    console.error('Error voting on poll:', error);
    res.status(500).send('Internal Server Error');
  }
});

// Close poll route
router.post('/polls/:id/close', async (req, res) => {
  try {
    const poll = await Poll.findById(req.params.id);

    // Validation
    if (!poll) {
      return res.status(404).send('Poll not found');
    }

    // Set poll status
    poll.status = 'Closed';

    await poll.save();
    res.redirect(`/polls/${poll._id}`);
  } catch (error) {
    console.error('Error closing poll:', error);
    res.status(500).send('Internal Server Error');
  }
});

// Export poll routes
export default router;