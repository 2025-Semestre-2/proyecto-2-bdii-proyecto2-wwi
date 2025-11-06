const sql = require('mssql');

const config = {
  user: 'sa',
  password: 'Dcg250808',
  server: 'localhost',  // SQL Server local en WSL
  port: 1433,
  database: 'WideWorldImporters',
  options: {
    encrypt: false,  // Para conexiones locales en WSL
    trustServerCertificate: true,
    enableArithAbort: true
  }
};

module.exports = { sql, config };