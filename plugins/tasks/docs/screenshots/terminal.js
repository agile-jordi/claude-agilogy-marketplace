// <div class="footer" data-branch data-ctx data-plus data-minus [data-prompt]>: Claude Code's prompt and status line.
const bar = (percent, width) => {
  const on = Math.max(1, Math.round(percent * width / 100))
  return `<span class="g">${'█'.repeat(on)}</span><span class="gray">${'█'.repeat(width - on)}</span>`
}
for (const footer of document.querySelectorAll('.footer')) {
  const { branch, ctx, plus, minus, prompt = '' } = footer.dataset
  const sep = '<span class="dim">│</span>'
  footer.innerHTML = `<pre class="rule">❯ ${prompt}<span class="cur"> </span></pre>` +
    `<pre class="status">  🌿 <span class="br">${branch}</span> ${sep} ctx 🟢 ${bar(+ctx, 20)} <span class="g">${ctx}%</span> ` +
    `${sep} 5h 🟢 ${bar(32, 10)} <span class="g">32%</span> 2h05m ${sep} 7d 🟢 ${bar(24, 10)} <span class="g">24%</span> 3d02h ` +
    `${sep} <span class="g">+${plus}</span> <span class="r">-${minus}</span> ${sep} 🤖 <span class="m">Opus 5.5</span>\n` +
    `  👤 ada <span class="dim">~/src</span><span class="path">/acme-shop</span>\n` +
    `  <span class="mode">⏵⏵ accept edits on</span> <span class="dim">(shift+tab to cycle)</span></pre>`
}

// A terminal draws an emoji two columns wide: give each one that width, so the columns line up.
const emoji = /(\p{Emoji_Presentation}|\p{Extended_Pictographic}️)/u
const walker = document.createTreeWalker(document.body, NodeFilter.SHOW_TEXT)
const texts = []
while (walker.nextNode()) texts.push(walker.currentNode)
for (const text of texts) {
  const parts = text.data.split(emoji)
  if (parts.length === 1) continue
  const fragment = document.createDocumentFragment()
  parts.forEach((part, i) => {
    if (i % 2 === 0) { if (part) fragment.append(part) } else {
      const span = document.createElement('span')
      span.className = 'e'
      span.textContent = part
      fragment.append(span)
    }
  })
  text.replaceWith(fragment)
}
