FROM nginx:alpine

COPY index.html /usr/share/nginx/html/index.html
COPY style.css /usr/share/nginx/html/style.css
COPY responsive.css /usr/share/nginx/html/responsive.css
COPY config.js /usr/share/nginx/html/config.js
COPY api.js /usr/share/nginx/html/api.js
COPY auth.js /usr/share/nginx/html/auth.js
COPY app.js /usr/share/nginx/html/app.js
COPY nginx.conf /etc/nginx/conf.d/default.conf

EXPOSE 80
