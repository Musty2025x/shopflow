// routes/cart.js
const router = require('express').Router();
const { pool } = require('../config/db');
const { auth } = require('../middleware/auth');

// GET /api/cart
router.get('/', auth, async (req, res) => {
  try {
    const [items] = await pool.execute(
      `SELECT ci.id, ci.quantity, p.id AS product_id, p.name, p.price, p.image_url, p.stock
       FROM cart_items ci JOIN products p ON ci.product_id = p.id
       WHERE ci.user_id = ?`, [req.user.id]
    );
    const total = items.reduce((sum, i) => sum + i.price * i.quantity, 0);
    res.json({ items, total: total.toFixed(2) });
  } catch (err) { res.status(500).json({ error: err.message }); }
});

// POST /api/cart
router.post('/', auth, async (req, res) => {
  try {
    const { product_id, quantity = 1 } = req.body;
    await pool.execute(
      `INSERT INTO cart_items (user_id, product_id, quantity) VALUES (?,?,?)
       ON DUPLICATE KEY UPDATE quantity = quantity + ?`,
      [req.user.id, product_id, quantity, quantity]
    );
    res.status(201).json({ message: 'Added to cart' });
  } catch (err) { res.status(500).json({ error: err.message }); }
});

// PUT /api/cart/:id
router.put('/:id', auth, async (req, res) => {
  try {
    const { quantity } = req.body;
    if (quantity < 1) {
      await pool.execute('DELETE FROM cart_items WHERE id=? AND user_id=?', [req.params.id, req.user.id]);
      return res.json({ message: 'Item removed' });
    }
    await pool.execute('UPDATE cart_items SET quantity=? WHERE id=? AND user_id=?', [quantity, req.params.id, req.user.id]);
    res.json({ message: 'Cart updated' });
  } catch (err) { res.status(500).json({ error: err.message }); }
});

// DELETE /api/cart/:id
router.delete('/:id', auth, async (req, res) => {
  try {
    await pool.execute('DELETE FROM cart_items WHERE id=? AND user_id=?', [req.params.id, req.user.id]);
    res.json({ message: 'Item removed' });
  } catch (err) { res.status(500).json({ error: err.message }); }
});

module.exports = router;
