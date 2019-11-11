server {
    root /var/www/example.com/html;
    index index.html index.htm index.nginx-debian.html;
    server_name example.com www.example.com;
    location / {
            try_files $uri $uri/ =404;
    }

    server_tokens off;

    # cache informations about FDs, frequently accessed files
    # can boost performance, but you need to test those values
    open_file_cache max=200000 inactive=20s;
    open_file_cache_valid 30s;
    open_file_cache_min_uses 2;
    open_file_cache_errors on;
    location ~* \.(ttf|eot|svg|woff|jpg|jpeg|png|ico|css|js)$ {
            expires 1y;
            add_header Cache-Controll public;
    }

    # reduce the data that needs to be sent over network -- for testing environment
    gzip on;
    gzip_min_length 1024;
    gzip_comp_level 9;
    gzip_vary on;
    gzip_disable msie6;
    gzip_proxied any;
    gzip_types
        # text/html is always compressed by HttpGzipModule
        text/css
        text/javascript
        text/xml
        text/plain
        text/x-component
        application/javascript
        application/x-javascript
        application/json
        application/xml
        application/rss+xml
        application/atom+xml
        font/truetype
        font/opentype
        application/vnd.ms-fontobject
        image/svg+xml;
    listen [::]:443 ssl http2 ipv6only=on; # managed by Certbot
    listen 443 ssl http2; # managed by Certbot

    #Provide here a direct path to your SSL certificates
    ssl_certificate /path/to/your/ssl/certificate/fullchain.pem; # managed by Certbot
    ssl_certificate_key /path/to/your/ssl/certificate/privkey.pem; # managed by Certbot
    include /etc/letsencrypt/options-ssl-nginx.conf; # managed by Certbot
    ssl_dhparam /etc/letsencrypt/ssl-dhparams.pem; # managed by Certbot
}

server {
    if ($host = www.example.com) {
        return 301 https://$host$request_uri;
    } # managed by Certbot
    if ($host = example.com) {
        return 301 https://$host$request_uri;
    } # managed by Certbot

    listen 80;
    listen [::]:80;
    server_name example.com www.example.com;
    return 404; # managed by Certbot
}
