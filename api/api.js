const express = require('express');
const { sql, config } = require('./config');

const clientesRoute = require('./routes/clients');
const proveedoresRoute = require('./routes/suppliers');
const inventarioRoute = require('./routes/inventory');
const ventasRoute = require('./routes/sales');
const estadisticasRoute = require('./routes/stats');

const app = express();
app.use(express.json());

let pool;

sql.connect(config)
  .then(p => {
    pool = p;
    console.log('Conectado a SQL Server');
  })
  .catch(error => {
    console.error('Error de conexión: ', error.message);
  });

app.use('/api/clientes', clientesRoute);
app.use('/api/proveedores', proveedoresRoute);
app.use('/api/inventario', inventarioRoute);
app.use('/api/ventas', ventasRoute);
app.use('/api/estadisticas', estadisticasRoute);

app.get('/', (req,res) => {
  res.send('API funcionando');
});

const PORT = 5000;
app.listen(PORT, () => {
  console.log(`🚀 Servidor escuchando en http://localhost:${PORT}`);
});
