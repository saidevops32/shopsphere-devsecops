let token = '';
const out = document.getElementById('out');
fetch('/api/products').then(r => r.json()).then(p => {
  const ul = document.getElementById('products');
  p.forEach(x => { const li = document.createElement('li'); li.textContent = `${x.name} - $${x.price}`; ul.appendChild(li); });
});
document.getElementById('login').onclick = async () => {
  const r = await fetch('/api/login', { method: 'POST', headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ username: 'demo', password: document.getElementById('pw').value }) });
  const j = await r.json(); token = j.token || ''; out.textContent = r.ok ? 'logged in' : JSON.stringify(j);
};
document.getElementById('orders').onclick = async () => {
  const r = await fetch('/api/orders', { headers: { Authorization: `Bearer ${token}` } });
  out.textContent = JSON.stringify(await r.json());
};
