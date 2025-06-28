import express from 'express';
import mongoose from 'mongoose';
import path from 'path';
import { engine } from 'express-handlebars';
import { fileURLToPath } from 'url';

// Get the current directory and filename
const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

const app = express();

// Connect to MongoDB
mongoose.connect('mongodb://localhost:27017/quickpoll')
  .then(() => console.log('MongoDB connected'))
  .catch(err => console.error('MongoDB connection error:', err));

// Handlebars setup
app.engine('handlebars', engine({
  helpers: {
    ifCond: function (a, b, options) {
      if (a === b) {
        return options.fn(this);
      }
      return options.inverse(this);
    },
    join: function (array, separator) {
      return array.join(separator);
    }
  },
  runtimeOptions: {
    allowProtoPropertiesByDefault: true,
    allowProtoMethodsByDefault: true
  }
}));
app.set('view engine', 'handlebars');
app.set('views', path.join(__dirname, 'views'));

// Middleware
app.use(express.urlencoded({ extended: true }));
app.use(express.static(path.join(__dirname, 'public')));

// Routes
import pollRoutes from './routes/pollRoutes.js';
app.use('/', pollRoutes);

// Start server
const PORT = process.env.PORT || 3000;
app.listen(PORT, () => {
  console.log(`Server running on http://localhost:${PORT}`);
});