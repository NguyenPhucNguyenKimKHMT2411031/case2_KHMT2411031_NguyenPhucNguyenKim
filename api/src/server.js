require('dotenv').config();
const app = require('./app');
const connectDB = require('./config/database');

connectDB()
  .then(() => app.listen(process.env.PORT, () => console.log('API chạy cổng ' + process.env.PORT)))
  .catch((e) => console.error('Lỗi kết nối DB:', e.message));