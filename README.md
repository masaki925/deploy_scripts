
# おおまかな作業の流れ

* 自分のbranch をpush
* staging branch を↑のbranch に合わせて、push
  * 1つのやり方は、下記
    <pre>
      git checkout staging
      git reset --hard (branch name)
      git push origin staging # 必要であれば、問題ないことを確認したうえで--force をつける
    </pre>
  * こうすることで、staging 環境に反映される(他の人が確認できるようになる)。
  * あらかじめ最新のmaster にrebase されているようにすること
    * デグレを防ぐため。
* staging にて、Product Orner (以下PO) に確認してもらう
* よければ、Pull Request (以下PR) を投げる
* レビュアー がPR を確認
* (コードの修正点があれば、確認<=> 修正を繰り返す)
* 問題なければ本番にデプロイ
  * レビュアーがPR のbranch をmaster にマージ
    * こうすることで、production 環境にデプロイされる

# その他

crontab example:

<pre>
* * * * *  source /etc/profile.d/rbenv.sh && cd /home/cyuser/work/ && PATH=$PATH:/usr/local/bin sh auto_deploy.sh staging.ini >> /var/log/compathy/auto_deploy_staging_`date +\%Y\%m\%d`.log
</pre>

