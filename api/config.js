const sql = require('mssql');

const config = {
    server: 'localhost',
    database: 'WideWorldImporters',
    user: 'sa',
    password: '*NoTieneClave1290',
    options: { encrypt: false, trustServerCertificate: true}
};

module.exports = { sql, config };