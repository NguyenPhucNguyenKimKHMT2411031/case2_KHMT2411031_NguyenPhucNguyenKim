const app = require('./app');
const mongoose = require('mongoose');
require('dotenv').config();

const PORT = process.env.PORT || 3000;
const MONGO_URI = process.env.MONGO_URI || 'mongodb://127.0.0.1:27017/taskmanager';

console.log('Đang kết nối MongoDB...');

mongoose.connect(MONGO_URI)
  .then(() => {
    console.log('--> MongoDB kết nối thành công!');
    app.listen(PORT, () => {
      console.log(`--> Server đang chạy thành công tại http://localhost:${PORT}`);
    });
  })
  .catch((err) => {
    console.error('--> LỖI KẾT NỐI MONGODB:', err.message);
  });