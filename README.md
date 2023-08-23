# memo

volumes:
      - ./workspace:/workspace
      - ./config/argv.json:/home/coder/.local/share/code-server/User/argv.json
      - ./config/settings.json:/home/coder/.local/share/code-server/User/settings.json
      - ./config/languagepacks.json:/home/coder/.local/share/code-server/languagepacks.json
