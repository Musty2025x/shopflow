// config/seed.js — seeds sample data into RDS
require('dotenv').config();
const { pool } = require('./db');
const bcrypt = require('bcryptjs');

async function seed() {
  console.log('🌱 Seeding database...');

  // Categories
  const categories = [
    { name: 'Electronics',  slug: 'electronics',  description: 'Gadgets and devices' },
    { name: 'Clothing',     slug: 'clothing',      description: 'Fashion and apparel' },
    { name: 'Home & Garden',slug: 'home-garden',   description: 'Home essentials' },
    { name: 'Sports',       slug: 'sports',        description: 'Fitness and outdoors' },
  ];

  for (const cat of categories) {
    await pool.execute(
      `INSERT IGNORE INTO categories (name, slug, description) VALUES (?,?,?)`,
      [cat.name, cat.slug, cat.description]
    );
  }
  console.log('  ✅ Categories seeded');

  // Products
  const products = [
    { name: 'Wireless Noise-Cancelling Headphones', slug: 'wireless-headphones', description: 'Premium sound with 40h battery life and active noise cancellation.', price: 199.99, stock: 45, category: 'electronics', image_url: 'https://images.unsplash.com/photo-1505740420928-5e560c06d30e?w=400', featured: true },
    { name: 'Mechanical Keyboard RGB', slug: 'mechanical-keyboard', description: 'Tactile switches with customisable RGB backlighting. TKL layout.', price: 129.99, stock: 30, category: 'electronics', image_url: 'https://images.unsplash.com/photo-1601445638532-1f1d4ea1d052?w=400', featured: false },
    { name: '4K Webcam Pro', slug: '4k-webcam', description: 'Ultra-sharp 4K streaming camera with built-in ring light.', price: 89.99, stock: 60, category: 'electronics', image_url: 'https://images.unsplash.com/photo-1587826080692-f439cd0b70da?w=400', featured: true },
    { name: 'Premium Cotton Hoodie', slug: 'premium-hoodie', description: 'Heavyweight 400gsm cotton. Oversized fit. Multiple colours.', price: 59.99, stock: 120, category: 'clothing', image_url: 'https://images.unsplash.com/photo-1556821840-3a63f15732ce?w=400', featured: true },
    { name: 'Running Shorts Pro', slug: 'running-shorts', description: 'Lightweight moisture-wicking fabric with zip pocket.', price: 34.99, stock: 80, category: 'sports', image_url: 'https://images.unsplash.com/photo-1591195853828-11db59a44f43?w=400', featured: false },
    { name: 'Bamboo Desk Organiser', slug: 'bamboo-organiser', description: 'Eco-friendly desktop storage with 6 compartments.', price: 29.99, stock: 55, category: 'home-garden', image_url: 'https://images.unsplash.com/photo-1593642632559-0c6d3fc62b89?w=400', featured: false },
    { name: 'Smart Water Bottle', slug: 'smart-water-bottle', description: 'Tracks hydration, glows to remind you to drink. 750ml.', price: 44.99, stock: 70, category: 'sports', image_url: 'https://images.unsplash.com/photo-1602143407151-7111542de6e8?w=400', featured: true },
    { name: 'Ceramic Pour-Over Coffee Set', slug: 'coffee-set', description: 'Hand-crafted ceramic dripper + carafe. Makes perfect pour-over.', price: 54.99, stock: 35, category: 'home-garden', image_url: 'https://images.unsplash.com/photo-1495474472287-4d71bcdd2085?w=400', featured: false },
  ];

  const [cats] = await pool.execute('SELECT id, slug FROM categories');
  const catMap = Object.fromEntries(cats.map(c => [c.slug, c.id]));

  for (const p of products) {
    await pool.execute(
      `INSERT IGNORE INTO products (name, slug, description, price, stock, category_id, image_url, featured)
       VALUES (?,?,?,?,?,?,?,?)`,
      [p.name, p.slug, p.description, p.price, p.stock, catMap[p.category], p.image_url, p.featured]
    );
  }
  console.log('  ✅ Products seeded');

  // Admin user
  const hash = await bcrypt.hash('admin123', 10);
  await pool.execute(
    `INSERT IGNORE INTO users (name, email, password, role) VALUES (?,?,?,?)`,
    ['Admin', 'admin@shopflow.com', hash, 'admin']
  );
  console.log('  ✅ Admin user: admin@shopflow.com / admin123');

  console.log('✅ Seeding complete');
  process.exit(0);
}

seed().catch(err => {
  console.error('Seed failed:', err);
  process.exit(1);
});
