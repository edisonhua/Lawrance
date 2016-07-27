{
    n = split($9,t,/[()+:]/)
    hours = t[n-3]*24 + t[n-2] + t[n-1]/60
    tot[$4][$1] += hours
}
END {
    for (month in tot) {
        print "["month"]"
        for (user in tot[month]) {
            print user, tot[month][user] "hours"
        }
    }
}