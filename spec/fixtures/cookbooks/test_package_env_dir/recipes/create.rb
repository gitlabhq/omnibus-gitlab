vars = {
  'FOO' => 'Lorem',
  'BAR' => 'Ipsum'
}

env_dir '/tmp/env' do
  variables vars
end
