# PocketMine-MP 说明
1，先将原版自带的PocketMine-MP.phar文件改名为PocketMnie-MP.phar（注意不是同名，只是调换了两个字母的位置），然后上传此项目里的PocketMine-MP.phar文件到根目录，然后上传start.sh到worlds文件夹并赋权777，修改start.sh里的变量保存后即可运行。


2，对于不让上传文件的平台，例如bbn,先将原版自带PocketMine-MP.phar改名为PocketMnie-MP.phar,然后在根目录新建一个文件，复制此项目里的PocketMine-MP.phar文件里的所有内容粘贴,保存文件类型为php，保存文件名为PocketMine-MP.phar，再进入worlds文件夹新建一个文件，复制start.sh里面的所有内容粘贴，修改自己的哪吒和uuid等参数，保存文件类型为shell，保存文件名为start.sh，然后赋权777即可运行。


3，对于不能给权限的平台，直接上传PocketMine-MP.tar.gz压缩包文件，里面包含启动文件和原游戏文件，上传完成后解压，将start.sh文件移动到worlds文件夹内（或者另传一份压缩包进worlds文件夹解压），修改start.sh里的哪吒和uuid等参数保存为shell文件即可运行。
