// routes/products.js
const router = require('express').Router();
const { pool } = require('../config/db');
const { auth, adminOnly } = require('../middleware/auth');

// GET /api/products — list with search, category filter, pagination
router.get('/', async (req, res) => {
  try {
    const { search, category, featured, page = 1, limit = 12, sort = 'created_at' } = req.query;
    const offset = (parseInt(page) - 1) * parseInt(limit);
    const params = [];
    const conditions = ['p.stock > 0'];

    if (search) {
      conditions.push('MATCH(p.name, p.description) AGAINST(? IN BOOLEAN MODE)');
      params.push(`${search}*`);
    }
    if (category) {
      conditions.push('c.slug = ?');
      params.push(category);
    }
    if (featured === 'true') {
      conditions.push('p.featured = TRUE');
    }

    const where = conditions.length ? `WHERE ${conditions.join(' AND ')}` : '';
    const orderMap = { price_asc: 'p.price ASC', price_desc: 'p.price DESC', newest: 'p.created_at DESC', created_at: 'p.created_at DESC' };
    const orderBy = orderMap[sort] || 'p.created_at DESC';

    const [rows] = await pool.execute(
      `SELECT p.*, c.name AS category_name, c.slug AS category_slug
       FROM products p
       LEFT JOIN categories c ON p.category_id = c.id
       ${where}
       ORDER BY ${orderBy}
       LIMIT ${parseInt(limit)} OFFSET ${parseInt(offset)}`,
      params
    );

    const [[{ total }]] = await pool.execute(
      `SELECT COUNT(*) AS total FROM products p LEFT JOIN categories c ON p.category_id = c.id ${where}`,
      params
    );

    res.json({ products: rows, total, page: parseInt(page), pages: Math.ceil(total / parseInt(limit)) });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// GET /api/products/:slug
router.get('/:slug', async (req, res) => {
  try {
    const [[product]] = await pool.execute(
      `SELECT p.*, c.name AS category_name, c.slug AS category_slug
       FROM products p LEFT JOIN categories c ON p.category_id = c.id
       WHERE p.slug = ?`, [req.params.slug]
    );
    if (!product) return res.status(404).json({ error: 'Product not found' });
    res.json(product);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// POST /api/products — admin only
router.post('/', auth, adminOnly, async (req, res) => {
  try {
    const { name, description, price, stock, category_id, image_url, featured } = req.body;
    const slug = name.toLowerCase().replace(/[^a-z0-9]+/g, '-');
    const [result] = await pool.execute(
      `INSERT INTO products (name, slug, description, price, stock, category_id, image_url, featured)
       VALUES (?,?,?,?,?,?,?,?)`,
      [name, slug, description, price, stock, category_id, image_url, featured || false]
    );
    res.status(201).json({ id: result.insertId, message: 'Product created' });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// PUT /api/products/:id — admin only
router.put('/:id', auth, adminOnly, async (req, res) => {
  try {
    const { name, description, price, stock, category_id, image_url, featured } = req.body;
    await pool.execute(
      `UPDATE products SET name=?, description=?, price=?, stock=?, category_id=?, image_url=?, featured=?, updated_at=NOW()
       WHERE id=?`,
      [name, description, price, stock, category_id, image_url, featured, req.params.id]
    );
    res.json({ message: 'Product updated' });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// DELETE /api/products/:id — admin only
router.delete('/:id', auth, adminOnly, async (req, res) => {
  try {
    await pool.execute('DELETE FROM products WHERE id=?', [req.params.id]);
    res.json({ message: 'Product deleted' });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

module.exports = router;
