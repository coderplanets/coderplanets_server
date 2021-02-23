content =
  // table
  '<div class="article-viewer-wrapper"><div class="table-wrapper">\n         <table>\n           <tbody>\n             <tr><td><div class="table-cell align-left">cell 0</div></td><td style="width: 180px"><div class="table-cell align-center">cell 1</div></td><td><div class="table-cell align-right">cell 2</div></td><td><div class="table-cell align-left">cell 3</div></td></tr><tr><td><div class="table-cell align-left">cell 4</div></td><td><div class="table-cell align-left">cell 5</div></td><td><div class="table-cell align-left"></div></td></tr>\n           </tbody>\n         </table>\n       </div></div>';

// header
// '<div class="article-viewer-wrapper"><div class="header-wrapper">\n        <div class="eyebrow-title">eyebrow title content</div>\n        <h1 class="header">header content</h1>\n      </div></div>';
// '<div class="article-viewer-wrapper"><div class="header-wrapper">\n        <h1 class="header">header content</h1>\n        <div class="footer-title">footer title content</div>\n      </div></div>';
// '<div class="article-viewer-wrapper"><div class="header-wrapper">\n        <div class="eyebrow-title">eyebrow title content</div>\n        <h1 class="header">header content</h1>\n        <div class="footer-title">footer title content</div>\n      </div></div>';

// list
// '<div class="article-viewer-wrapper"><div class="list-wrapper"><div class="list-item ">\n        <div class="list__item-order-prefix">1.</div>\n        <div class="list-label list-label__default" data-index="0">\n        label\n      </div>\n        <div class="list-item-text">\n        一个带着中文的很长的句子。一个带着中文的很长的句子。一个带着中文的很长的句子。一个带着中文的很长的句子。一个带着中文的很长的句子。一个带着中文的很长的句子。一个带着中文的很长的句子。一个带着中文的很长的句子。一个带着中文的很长的句子。\n      </div>\n      </div><div class="list-item ">\n        <div class="list__item-order-prefix">2.</div>\n        <div class="list-label list-label__default" data-index="0">\n        label\n      </div>\n        <div class="list-item-text">\n        list item\n      </div>\n      </div><div class="list-item list-indent-1">\n        <div class="list__item-order-prefix">2.1</div>\n        <div class="list-label list-label__green" data-index="1">\n        green\n      </div>\n        <div class="list-item-text">\n        list item\n      </div>\n      </div></div></div>';

const articleEl = document.getElementById("article");

articleEl.innerHTML = content;
