$i=0; Get-Content ANDRE_20211229-30_15.txt -ReadCount 1000 | %{$i++; $_ | Out-File ANDRE_20211229-30_15_99$i.txt}
