# تشغيل PostgreSQL محلياً للتطوير (Windows)

## المتطلبات
- [Docker Desktop](https://www.docker.com/products/docker-desktop/)

## التشغيل

```powershell
cd d:\sport
docker compose up -d postgres
```

## إعداد API

انسخ أو عدّل `SportsApp/Api/appsettings.Development.json`:

```json
{
  "ConnectionStrings": {
    "Default": "Host=127.0.0.1;Port=5432;Database=riyada;Username=riyada;Password=riyada_dev"
  }
}
```

أو عيّن متغير البيئة:

```powershell
$env:ConnectionStrings__Default = "Host=127.0.0.1;Port=5432;Database=riyada;Username=riyada;Password=riyada_dev"
cd d:\sport\SportsApp\Api
dotnet run
```

## التحقق

```powershell
docker compose ps
curl http://localhost:5000/api/health
```

## إيقاف

```powershell
docker compose down
```

## نسخ احتياطي يدوي

```bash
./deploy/backup-db.sh
```
