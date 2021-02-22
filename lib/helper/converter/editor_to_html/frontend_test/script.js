content =
  '<div class="article-viewer-wrapper"><div class="list-wrapper"><div class="list-item ">\n        <div class="list__item-unorder-prefix"></div>\n        <div class="list-label list-label__default" data-index="0">\n        label\n      </div>\n        <div class="list-item-text">\n        一个带着中文的很长的句子。一个带着中文的很长的句子。一个带着中文的很长的句子。一个带着中文的很长的句子。一个带着中文的很长的句子。一个带着中文的很长的句子。一个带着中文的很长的句子。一个带着中文的很长的句子。一个带着中文的很长的句子。\n      </div>\n      </div><div class="list-item ">\n        <div class="list__item-unorder-prefix"></div>\n        <div class="list-label list-label__default" data-index="0">\n        label\n      </div>\n        <div class="list-item-text">\n        list item\n      </div>\n      </div><div class="list-item list-indent-1">\n        <div class="list__item-unorder-prefix"></div>\n        <div class="list-label list-label__green" data-index="1">\n        green\n      </div>\n        <div class="list-item-text">\n        list item\n      </div>\n      </div></div></div>';

const articleEl = document.getElementById("article");

articleEl.innerHTML = content;
