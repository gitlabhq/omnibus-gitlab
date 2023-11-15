database_objects 'postgresql' do
  pg_helper PgHelper.new(node)
  account_helper AccountHelper.new(node)
end
