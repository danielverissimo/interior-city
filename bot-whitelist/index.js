import { readFile } from 'node:fs/promises';
import {
  ActionRowBuilder, ButtonBuilder, ButtonStyle, Client, Events, GatewayIntentBits,
  LabelBuilder, MessageFlags, ModalBuilder, TextDisplayBuilder, TextInputBuilder, TextInputStyle,
} from 'discord.js';
import { gradeQuiz, validateQuiz } from './quiz.js';

const guildId = process.env.DISCORD_GUILD_ID;
const roleId = process.env.DISCORD_WHITELIST_ROLE_ID;
const token = process.env.DISCORD_BOT_TOKEN;
if (!/^\d{17,20}$/.test(guildId ?? '') || !/^\d{17,20}$/.test(roleId ?? '') || !token?.trim()) {
  throw new Error('Preencha o token do bot e os IDs do servidor e do cargo no arquivo .env.');
}

const quiz = validateQuiz(JSON.parse(await readFile(new URL('./questionario.json', import.meta.url), 'utf8')));
const client = new Client({ intents: [GatewayIntentBits.Guilds] });
const active = new Map();
const durationMs = 10 * 60_000;

function questionText(question) {
  const options = question.options.map((option, i) => `**${i + 1}.** ${option}`).join('\n');
  return `${question.prompt}\n\n${options}`;
}

function questionMessage(session) {
  const index = session.answers.length;
  const button = new ButtonBuilder()
    .setCustomId(`wl-question:${session.command.id}:${index}`)
    .setStyle(ButtonStyle.Primary)
    .setLabel('Digitar resposta');
  return {
    content: `**Whitelist da Interior City**\nPergunta ${index + 1} de ${quiz.questions.length}\n\n${questionText(quiz.questions[index])}`,
    components: [new ActionRowBuilder().addComponents(button)],
  };
}

function closeSession(userId, session) {
  clearTimeout(session.timer);
  if (active.get(userId) === session) active.delete(userId);
}

async function startQuiz(interaction) {
  const userId = interaction.user.id;
  if (active.has(userId)) {
    await interaction.reply({ content: 'Você já tem um questionário aberto.', flags: MessageFlags.Ephemeral });
    return;
  }
  const session = { command: interaction, answers: [], busy: true };
  active.set(userId, session);
  try {
    await interaction.deferReply({ flags: MessageFlags.Ephemeral });
    session.member = await interaction.guild.members.fetch({ user: userId, force: true });
    if (session.member.roles.cache.has(roleId)) {
      await interaction.editReply('Sua whitelist já está aprovada. Você pode entrar na cidade.');
      closeSession(userId, session);
      return;
    }

    await interaction.editReply(questionMessage(session));
    session.timer = setTimeout(() => {
      closeSession(userId, session);
      void interaction.editReply({
        content: 'O questionário expirou. Use /whitelist para recomeçar.',
        components: [],
      }).catch(() => {});
    }, durationMs);
    session.busy = false;
  } catch (error) {
    closeSession(userId, session);
    throw error;
  }
}

async function completeQuiz(session) {
  const { score, mistakes, percentage, minimumScore, approved } = gradeQuiz(quiz, session.answers);
  const result = `**Resultado**\n✅ Acertos: **${score}**\n❌ Erros: **${mistakes}**\nAproveitamento: **${percentage.toLocaleString('pt-BR', { maximumFractionDigits: 2 })}%**\nMínimo: **${quiz.minimumPercentage}%** (${minimumScore} acertos)`;
  let status = 'Whitelist reprovada. Revise as regras e tente novamente com /whitelist.';
  if (approved) {
    try {
      await session.member.roles.add(roleId, 'Aprovado no questionário de whitelist da Interior City');
      status = '**Whitelist aprovada!** Entre no FiveM com esta conta do Discord aberta para registrar seu personagem.';
    } catch (error) {
      console.error('[whitelist] Falha ao atribuir o cargo:', error.code ?? error.name);
      status = 'Você atingiu a nota mínima, mas o Discord não liberou o cargo. Avise a equipe.';
    }
  }
  await session.command.editReply({ content: `${result}\n\n${status}`, components: [] });
}

async function handleAnswer(interaction, session, action, attempt, index) {
  if (!session || session.busy || session.command.id !== attempt || session.answers.length !== Number(index)) {
    await interaction.reply({ content: 'Esta pergunta já passou ou expirou.', flags: MessageFlags.Ephemeral });
    return;
  }

  if (action === 'question' && interaction.isButton()) {
    const questionIndex = session.answers.length;
    const input = new TextInputBuilder().setCustomId('answer').setStyle(TextInputStyle.Short)
      .setMinLength(1).setMaxLength(1).setRequired(true);
    await interaction.showModal(new ModalBuilder().setTitle(`Pergunta ${questionIndex + 1}`)
      .setCustomId(`wl-answer:${attempt}:${index}`)
      .addTextDisplayComponents(new TextDisplayBuilder().setContent(questionText(quiz.questions[questionIndex])))
      .addLabelComponents(new LabelBuilder().setLabel('Digite 1, 2 ou 3').setTextInputComponent(input)));
    return;
  }

  if (action !== 'answer' || !interaction.isModalSubmit()) return;
  const value = interaction.fields.getTextInputValue('answer').trim();
  if (!/^[1-3]$/.test(value)) {
    await interaction.reply({ content: 'Digite apenas 1, 2 ou 3 e tente esta pergunta novamente.', flags: MessageFlags.Ephemeral });
    return;
  }

  session.busy = true;
  try {
    await interaction.deferUpdate();
    if (active.get(interaction.user.id) !== session) return;
    session.answers.push(Number(value) - 1);
    if (session.answers.length === quiz.questions.length) {
      clearTimeout(session.timer);
      await completeQuiz(session);
      closeSession(interaction.user.id, session);
    } else {
      await session.command.editReply(questionMessage(session));
    }
  } catch (error) {
    closeSession(interaction.user.id, session);
    throw error;
  } finally {
    session.busy = false;
  }
}

client.once(Events.ClientReady, async () => {
  try {
    const guild = await client.guilds.fetch(guildId);
    await guild.members.fetchMe();
    const role = await guild.roles.fetch(roleId);
    if (!role || role.id === guild.id || role.managed || !role.editable) {
      throw new Error('O cargo de aprovado precisa estar abaixo do cargo do bot, que deve ter Gerenciar Cargos.');
    }
    await guild.commands.create({
      name: 'whitelist',
      description: 'Responder o questionário de acesso à Interior City',
    });
    console.log('[whitelist] Bot conectado. Comando /whitelist disponível.');
  } catch (error) {
    console.error('[whitelist] Inicialização falhou:', error.code ?? error.message);
    client.destroy();
    process.exitCode = 1;
  }
});

client.on(Events.InteractionCreate, async interaction => {
  if (interaction.guildId !== guildId) return;
  try {
    if (interaction.isChatInputCommand() && interaction.commandName === 'whitelist') {
      await startQuiz(interaction);
    } else if (interaction.isButton() || interaction.isModalSubmit()) {
      const match = /^wl-(question|answer):(\d+):(\d+)$/.exec(interaction.customId);
      if (match) await handleAnswer(interaction, active.get(interaction.user.id), ...match.slice(1));
    }
  } catch (error) {
    console.error('[whitelist] Falha na interação:', error.code ?? error.name);
    const response = { content: 'Não foi possível concluir a whitelist. Tente novamente em instantes.', components: [] };
    if (interaction.deferred || interaction.replied) {
      await interaction.editReply(response).catch(() => {});
    } else {
      await interaction.reply({ ...response, flags: MessageFlags.Ephemeral }).catch(() => {});
    }
  }
});

try {
  await client.login(token.trim());
} catch (error) {
  console.error('[whitelist] O bot não conectou. Confira o token e a rede.', error.code ?? error.name);
  process.exitCode = 1;
}
