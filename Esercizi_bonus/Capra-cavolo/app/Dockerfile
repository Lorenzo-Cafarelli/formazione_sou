FROM alpine:latest

# Installa iputils per un ping più affidabile (opzionale su alpine recenti ma consigliato)
RUN apk add --no-cache iputils

COPY logic.sh /logic.sh
RUN chmod +x /logic.sh

CMD ["/logic.sh"]