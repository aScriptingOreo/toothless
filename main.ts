import express from 'express';
import path from 'path';
const app = express();
import dotenv from 'dotenv';

dotenv.config();

const port = process.env.PORT || 3000;

app.get('/', (req, res) => {
  res.sendFile(path.join(__dirname, 'index.html'));
});
app.use('/assets', express.static(path.join(__dirname, 'assets')));


app.listen(port, () => {
  console.log(`Server is running at http://localhost:${port}`);
});