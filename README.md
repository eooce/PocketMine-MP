# PocketMine-MP 说明
1，先将原版自带PocketMine-MP.phar改名为PocketMine--MP.phar，然后上传PocketMine-MP.phar和start.sh并赋权777，修改参数后即可运行。

2，对于不让上传文件的平台，例如bbn,新建文件，复制PocketMine-MP.php里的内容,类型为php，保存文件名为PocketMine-MP.phar，再新建一个文件，复制start.sh里面的所有内容，
修改自己的哪吒和uuid等，保存文件类型为shell，保存文件名为start.sh，然后赋权777即可运行

3，对于不能给权限的平台，直接上传PocketMine-MP.tar.gz压缩包文件，里面包含启动文件和原游戏文件，上传完成后解压，修改start.sh里的哪吒和uuid等参数保存为shell文件即可运行。
