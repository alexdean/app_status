AppStatus::CheckCollection.configure do |c|
  c.add_check('ok') do
    [:ok, "looks good"]
  end
  c.add_description 'ok', <<-EOF
### OK Check

This check is always ok.
  EOF

  c.add_check('crit') do
    [:critical, "fail"]
  end
  c.add_description 'crit', <<-EOF
### Critical Check

This check is always critical.
  EOF

  c.add_check('no_description') do
    [:ok, 'check has no longer description']
  end

  c.add_check('no_details') do
    :ok
  end
  c.add_description('no_details', 'check only returns a status.')
end
