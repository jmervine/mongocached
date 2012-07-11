## Ruby 1.9.3p194
 
#### small string * 100000
<pre>
                 user     system      total        real
mongocached set  5.220000   0.380000   5.600000 (  5.616497)
memcached   set  1.440000   1.300000   2.740000 (  4.069726)
mongocached get 23.080000   3.030000  26.110000 ( 35.404997)
memcached   get  1.410000   1.330000   2.740000 (  3.750880)
</pre>
 
 
#### large hash * 100000
<pre>
                user     system      total        real
mongocached set 38.790000   1.130000  39.920000 ( 40.143200)
memcached   set 15.570000   2.300000  17.870000 ( 20.629503)
mongocached get 54.830000   4.260000  59.090000 ( 70.485417)
memcached   get 14.820000   1.430000  16.250000 ( 17.066038)
</pre>
