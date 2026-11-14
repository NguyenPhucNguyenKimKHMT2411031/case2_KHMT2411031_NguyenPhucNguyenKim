const PRIORITIES = ['low', 'medium', 'high'];
const STATUSES = ['todo', 'in_progress', 'completed'];

const isDate = (v) => !isNaN(new Date(v).getTime());

/** Trả về { errors: [], data: {...} }. partial=true dùng cho cập nhật. */
function validateTaskBody(body, { partial = false } = {}) {
  const errors = [];
  const data = {};

  if (!partial || body.title !== undefined) {
    const title = typeof body.title === 'string' ? body.title.trim() : '';
    if (!title) errors.push('Tên công việc không được để trống');
    else if (title.length > 200) errors.push('Tên công việc tối đa 200 ký tự');
    else data.title = title;
  }
  if (body.description !== undefined) data.description = String(body.description).trim();

  if (body.priority !== undefined) {
    if (!PRIORITIES.includes(body.priority)) errors.push('Mức độ ưu tiên không hợp lệ');
    else data.priority = body.priority;
  }
  if (body.status !== undefined) {
    if (!STATUSES.includes(body.status)) errors.push('Trạng thái không hợp lệ');
    else data.status = body.status;
  }
  for (const f of ['startDate', 'dueDate']) {
    if (body[f] !== undefined && body[f] !== null && body[f] !== '') {
      if (!isDate(body[f])) errors.push(`${f} không hợp lệ`);
      else data[f] = new Date(body[f]);
    } else if (body[f] === null || body[f] === '') {
      data[f] = null;
    }
  }
  return { errors, data };
}

module.exports = { PRIORITIES, STATUSES, validateTaskBody };