// src/controllers/menu.controller.js
const { get, run, all, cuid } = require('../config/database');
const { success, error, paginate } = require('../utils/response');

const fmt = (item) => ({
  id: item.id, name: item.name,
  price: item.price,
  formattedPrice: `Rp ${parseInt(item.price).toLocaleString('id-ID')}`,
  stock: item.stock, emoji: item.emoji,
  imageUrl: item.image_url, isAvailable: !!item.is_available,
  category: item.cat_id ? { id: item.cat_id, name: item.cat_name, label: item.cat_label } : null,
});

// GET /api/menu
const getMenu = (req, res) => {
  try {
    const { category, available, page = 1, limit = 50 } = req.query;
    const offset = (parseInt(page)-1) * parseInt(limit);
    let where = '1=1';
    const params = [];
    if (available !== undefined) { where += ' AND m.is_available = ?'; params.push(available==='true'?1:0); }
    if (category) { where += ' AND c.name = ?'; params.push(category.toLowerCase()); }
    const items = all(
      `SELECT m.*, c.id cat_id, c.name cat_name, c.label cat_label
       FROM menu_items m LEFT JOIN categories c ON m.category_id = c.id
       WHERE ${where} ORDER BY c.sort_order, m.name
       LIMIT ? OFFSET ?`,
      [...params, parseInt(limit), offset]);
    const [{ total }] = all(
      `SELECT COUNT(*) total FROM menu_items m LEFT JOIN categories c ON m.category_id=c.id WHERE ${where}`,
      params);
    return paginate(res, items.map(fmt),
      { page:parseInt(page), limit:parseInt(limit), total },
      'Data menu berhasil diambil');
  } catch (e) {
    return error(res, 'Gagal mengambil data menu', 500);
  }
};

// GET /api/menu/categories
const getCategories = (req, res) => {
  try {
    const cats = all('SELECT * FROM categories ORDER BY sort_order');
    return success(res, cats, 'Kategori berhasil diambil');
  } catch { return error(res, 'Gagal mengambil kategori', 500); }
};

// GET /api/menu/:id
const getMenuById = (req, res) => {
  try {
    const item = get(
      `SELECT m.*, c.id cat_id, c.name cat_name, c.label cat_label
       FROM menu_items m LEFT JOIN categories c ON m.category_id = c.id
       WHERE m.id = ?`, [req.params.id]);
    if (!item) return error(res, 'Menu tidak ditemukan', 404);
    return success(res, fmt(item));
  } catch { return error(res, 'Gagal mengambil detail menu', 500); }
};

// POST /api/menu
const createMenu = (req, res) => {
  try {
    const { name, price, stock, emoji, categoryId } = req.body;
    const id = cuid();
    run(`INSERT INTO menu_items(id,category_id,name,price,stock,emoji)
         VALUES(?,?,?,?,?,?)`,
        [id, categoryId, name, parseInt(price), parseInt(stock), emoji||'🍽️']);
    const item = get(
      `SELECT m.*, c.id cat_id, c.name cat_name, c.label cat_label
       FROM menu_items m LEFT JOIN categories c ON m.category_id = c.id
       WHERE m.id = ?`, [id]);
    return success(res, fmt(item), 'Menu berhasil ditambahkan', 201);
  } catch (e) {
    return error(res, 'Gagal membuat menu', 500);
  }
};

// PUT /api/menu/:id
const updateMenu = (req, res) => {
  try {
    const { name, price, stock, emoji, isAvailable } = req.body;
    const fields = [];
    const vals   = [];
    if (name        !== undefined) { fields.push('name=?');         vals.push(name); }
    if (price       !== undefined) { fields.push('price=?');        vals.push(parseInt(price)); }
    if (stock       !== undefined) { fields.push('stock=?');        vals.push(parseInt(stock)); }
    if (emoji       !== undefined) { fields.push('emoji=?');        vals.push(emoji); }
    if (isAvailable !== undefined) { fields.push('is_available=?'); vals.push(isAvailable?1:0); }
    if (!fields.length) return error(res, 'Tidak ada data yang diupdate', 400);
    fields.push("updated_at=datetime('now')");
    run(`UPDATE menu_items SET ${fields.join(',')} WHERE id=?`, [...vals, req.params.id]);
    const item = get(
      `SELECT m.*, c.id cat_id, c.name cat_name, c.label cat_label
       FROM menu_items m LEFT JOIN categories c ON m.category_id = c.id
       WHERE m.id = ?`, [req.params.id]);
    if (!item) return error(res, 'Menu tidak ditemukan', 404);
    return success(res, fmt(item), 'Menu berhasil diupdate');
  } catch { return error(res, 'Gagal mengupdate menu', 500); }
};

// DELETE /api/menu/:id
const deleteMenu = (req, res) => {
  try {
    run("UPDATE menu_items SET is_available=0,updated_at=datetime('now') WHERE id=?",
      [req.params.id]);
    return success(res, null, 'Menu berhasil dinonaktifkan');
  } catch { return error(res, 'Gagal menghapus menu', 500); }
};

module.exports = { getMenu, getCategories, getMenuById, createMenu, updateMenu, deleteMenu };
