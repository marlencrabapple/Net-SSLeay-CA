# NAME
catool is a tool for tooling around with CAs

# SYNOPSIS

## `catool newca`
```
[--class={root,(subordinate||intermediate); default="root"}
 {--name=<NAME>; default=*hostname*
  --country
  --locality
  --email
  | --subject=<ASN>
  }
 --parent=<DIR>
 --pathlen=<0-...>; default=0
 --openssl-config=<FILE>
 --certfile=<FILE>
 {--keyfile=<FILE> | --algorithm={rsa,ecc[=...]}; default="ecc=secp384r1"}
 ...]
```

## `catool ...` 
