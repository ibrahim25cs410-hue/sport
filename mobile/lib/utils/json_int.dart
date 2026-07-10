/// تحويل آمن للأرقام القادمة من JSON (int / double / string).
int? asInt(dynamic v) {
  if (v is int) return v;
  if (v is num) return v.toInt();
  if (v is String) return int.tryParse(v);
  return null;
}
