// routes/orders.js
const router = require('express').Router();
const { pool } = require('../config/db');
const { auth, adminOnly } = require('../middleware/auth');

// POST /api/orders — checkout from cart
router.post('/', auth, async (req, res) => {
  const conn = await pool.getConnection();
  try {
    await conn.beginTransaction();
    const { address } = req.body;

    const [cartItems] = await conn.execute(
      `SELECT ci.quantity, p.id, p.price, p.stock, p.name
       FROM cart_items ci JOIN products p ON ci.product_id = p.id
       WHERE ci.user_id = ?`, [req.user.id]
    );
    if (!cartItems.length) return res.status(400).json({ error: 'Cart is empty' });

    // Check stock
    for (const item of cartItems) {
      if (item.stock < item.quantity) {
        await conn.rollback();
        return res.status(400).json({ error: `Insufficient stock for: ${item.name}` });
      }
    }

    const total = cartItems.reduce((s, i) => s + i.price * i.quantity, 0);
    const [order] = await conn.execute(
      'INSERT INTO orders (user_id, total, address) VALUES (?,?,?)',
      [req.user.id, total.toFixed(2), address]
    );

    for (const item of cartItems) {
      await conn.execute(
        'INSERT INTO order_items (order_id, product_id, quantity, price) VALUES (?,?,?,?)',
        [order.insertId, item.id, item.quantity, item.price]
      );
      await conn.execute('UPDATE products SET stock = stock - ? WHERE id=?', [item.quantity, item.id]);
    }

    await conn.execute('DELETE FROM cart_items WHERE user_id=?', [req.user.id]);
    await conn.commit();
    res.status(201).json({ message: 'Order placed', order_id: order.insertId, total: total.toFixed(2) });
  } catch (err) {
    await conn.rollback();
    res.status(500).json({ error: err.message });
  } finally {
    conn.release();
  }
});

// GET /api/orders — my orders
router.get('/', auth, async (req, res) => {
  try {
    const [orders] = await pool.execute(
      `SELECT o.*, 
        (SELECT JSON_ARRAYAGG(JSON_OBJECT('name', p.name, 'qty', oi.quantity, 'price', oi.price))
         FROM order_items oi JOIN products p ON oi.product_id = p.id WHERE oi.order_id = o.id) AS items
       FROM orders o WHERE o.user_id = ? ORDER BY o.created_at DESC`, [req.user.id]
    );
    res.json(orders);
  } catch (err) { res.status(500).json({ error: err.message }); }
});

// GET /api/orders/all — admin
router.get('/all', auth, adminOnly, async (req, res) => {
  try {
    const [orders] = await pool.execute(
      `SELECT o.*, u.name AS customer_name, u.email AS customer_email
       FROM orders o JOIN users u ON o.user_id = u.id
       ORDER BY o.created_at DESC LIMIT 100`
    );
    res.json(orders);
  } catch (err) { res.status(500).json({ error: err.message }); }
});

// PUT /api/orders/:id/status — admin
router.put('/:id/status', auth, adminOnly, async (req, res) => {
  try {
    await pool.execute('UPDATE orders SET status=? WHERE id=?', [req.body.status, req.params.id]);
    res.json({ message: 'Status updated' });
  } catch (err) { res.status(500).json({ error: err.message }); }
});

module.exports = router;
