const express = require('express');
const cors = require('cors');

const app = express();

// 1. Cấu hình CORS
app.use(cors({
  origin: true,
  credentials: true,
  methods: ['GET', 'POST', 'PUT', 'DELETE', 'PATCH', 'OPTIONS'],
  allowedHeaders: ['Content-Type', 'Authorization', 'Accept', 'X-Requested-With']
}));

// 2. Parse Body JSON
app.use(express.json());

// 3. Health Check
app.get('/api/health', (req, res) => res.json({ ok: true }));

// 4. Khai báo các Routes chính
app.use('/api/auth', require('./routes/authRoutes'));
app.use('/api/users', require('./routes/userRoutes')); 
app.use('/api/tasks', require('./routes/taskRoutes'));

// Nested Routes & Notifications & Reports
app.use('/api/tasks/:id/assignees', require('./routes/assignmentRoutes'));
app.use('/api/tasks/:id/shares', require('./routes/taskShareRoutes'));
app.use('/api/notifications', require('./routes/notificationRoutes'));
app.use('/api', require('./routes/reportRoutes')); // Module E: Reports & Analytics

// 5. Middleware bắt lỗi 404 cho các Route không tồn tại
app.use((req, res, next) => {
  res.status(404).json({ message: `Không tìm thấy đường dẫn ${req.originalUrl}` });
});

// 6. Middleware xử lý lỗi hệ thống (500)
app.use((err, req, res, next) => {
  console.error(err);
  res.status(err.status || 500).json({ message: err.message || 'Lỗi hệ thống' });
});

const PORT = process.env.PORT || 3000;
app.listen(PORT, () => {
  console.log(`Server đang chạy tại http://localhost:${PORT}`);
});

module.exports = app;