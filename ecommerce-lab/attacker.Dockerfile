FROM kalilinux/kali-rolling
RUN apt-get update -qq && \
    apt-get install -y hydra curl nmap sqlmap nikto -qq 2>/dev/null
ENTRYPOINT ["sleep"]
CMD ["999999999"]
