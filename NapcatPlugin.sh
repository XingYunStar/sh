# Napcat 插件商店换源脚本
# 替换插件索引源为社区版
# 在napcat容器内使用，或者在napcat的终端使用

sed -i 's/NapNeko\/napcat-plugin-index/HolyFoxTeam\/napcat-plugin-community-index/g' ./napcat/napcat.mjs

echo "修复完成！请重启 Napcat 容器后查看插件商店。"
