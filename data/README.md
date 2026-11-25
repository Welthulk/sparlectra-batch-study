# Case files

The MATPOWER case files of the study are not part of this repository.
Download them with

```sh
julia scripts/download_cases.jl
```

The script loads each file from the MATPOWER release 8.1 on GitHub and
checks it against the SHA-256 of the file that was measured. The files keep
the licenses stated in their headers and in MATPOWER; see the "Data" section
of the README.
