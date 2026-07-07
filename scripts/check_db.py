import sqlite3
c = sqlite3.connect(r'd:\sport\SportsApp\Api\sports.db')
print('TABLES:', [r[0] for r in c.execute("SELECT name FROM sqlite_master WHERE type='table' ORDER BY 1")])
try:
    print('MIGRATIONS:', [r[0] for r in c.execute('SELECT MigrationId FROM __EFMigrationsHistory ORDER BY 1')])
except Exception as e:
    print('MIGRATIONS ERROR:', e)
