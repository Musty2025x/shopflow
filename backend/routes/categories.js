// routes/categories.js
const router = require('express').Router();
const { pool } = require('../config/db');
const { auth, adminOnly } = require('../middleware/auth');

router.get('/', async (req, res) => {
  try {
    const [rows] = await pool.execute(
      `SELECT c.*, COUNT(p.id) AS product_count
       FROM categories c LEFT JOIN products p ON c.id = p.category_id
       GROUP BY c.id ORDER BY c.name`
    );
    res.json(rows);
  } catch (err) { res.status(500).json({ error: err.message }); }
});

router.post('/', auth, adminOnly, async (req, res) => {
  try {
    const { name, description } = req.body;
    const slug = name.toLowerCase().replace(/[^a-z0-9]+/g, '-');
    const [r] = await pool.execute(
      'INSERT INTO categories (name, slug, description) VALUES (?,?,?)', [name, slug, description]
    );
    res.status(201).json({ id: r.insertId, message: 'Category created' });
  } catch (err) { res.status(500).json({ error: err.message }); }
});

module.exports = router;
