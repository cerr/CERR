% ISPGX returns 'pgx' if it is an pgx file
function fmt=ispgx(filename)
  fmt='';
  if length(filename)<4,
    return;
  end
  ext=lower(filename(end-3:end));
  if strcmp(ext,'.pgx'),
    fmt='pgx';
  end
  return;
