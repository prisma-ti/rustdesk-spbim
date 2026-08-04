// Shell da tela principal do HopToDeskSPBIM (Direção C aprovada em 29/jul: barra lateral
// no lugar das duas colunas originais do RustDesk). Ver decisão em
// _projetos/Acesso Remoto SPBIM/decisions/2026-07-29-redesign-cliente-direcao-c-shell-lateral.md
// no vault. O item selecionado é marcado só no quadrado do ícone (sem faixa atravessando a
// coluna) e o divisor acima do usuário sangra até as duas bordas, conforme pedido.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';

import '../../common.dart';
import '../../common/widgets/address_book.dart';
import '../../common/widgets/login.dart';
import '../../models/platform_model.dart';
import '../../models/server_model.dart';
import 'connection_page.dart';

enum SpbimSection { conectar, dispositivos, recentes, transferencias, ajuda }

class SpbimShell extends StatefulWidget {
  /// Cartão de avisos do sistema (instalação, permissões, atualização) que antes ficava na
  /// coluna esquerda. Continua existindo — só mudou de lugar, pra não perder função nenhuma.
  final Widget systemNotices;

  const SpbimShell({Key? key, required this.systemNotices}) : super(key: key);

  @override
  State<SpbimShell> createState() => _SpbimShellState();
}

class _SpbimShellState extends State<SpbimShell> {
  final Rx<SpbimSection> _section = SpbimSection.conectar.obs;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        widget.systemNotices,
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _rail(context),
              const VerticalDivider(width: 1),
              Expanded(child: Obx(() => _content(context))),
            ],
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------- rail --

  Widget _rail(BuildContext context) {
    final bg = Theme.of(context).colorScheme.background;
    return Container(
      width: 214,
      color: bg,
      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _brand(context),
          const SizedBox(height: 18),
          _navItem(context, SpbimSection.conectar, Icons.bolt_outlined, 'Conectar'),
          _navItem(context, SpbimSection.dispositivos, Icons.dns_outlined, 'Dispositivos'),
          _navItem(context, SpbimSection.recentes, Icons.history_outlined, 'Recentes'),
          _navItem(context, SpbimSection.transferencias, Icons.folder_outlined, 'Transferências'),
          _navItem(context, SpbimSection.ajuda, Icons.help_outline, 'Ajuda'),
          const Spacer(),
          _userRow(context),
        ],
      ),
    );
  }

  Widget _brand(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        children: [
          loadIcon(22),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              bind.mainGetAppNameSync(),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }

  Widget _navItem(
      BuildContext context, SpbimSection section, IconData icon, String label) {
    return Obx(() {
      final active = _section.value == section;
      final fg = active
          ? Theme.of(context).textTheme.titleLarge?.color
          : Theme.of(context).textTheme.bodySmall?.color;
      return InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () => _section.value = section,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            children: [
              Container(
                width: 30,
                height: 30,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: active ? MyTheme.idColor.withOpacity(0.14) : null,
                  border: Border.all(
                    color: active ? MyTheme.idColor : Colors.transparent,
                    width: 1.4,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 16, color: active ? MyTheme.idColor : fg),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 13.5,
                    color: fg,
                    fontWeight: active ? FontWeight.w600 : FontWeight.w400,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    });
  }

  Widget _userRow(BuildContext context) {
    return Obx(() {
      final logged = gFFI.userModel.isLogin;
      final label = logged ? gFFI.userModel.displayNameOrUserName : 'Não conectado';
      final initials = logged && label.isNotEmpty ? label.substring(0, 1).toUpperCase() : '?';
      return InkWell(
        onTap: logged ? null : loginDialog,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: -12),
          padding: const EdgeInsets.fromLTRB(20, 13, 12, 4),
          decoration: BoxDecoration(
            border: Border(top: BorderSide(color: Theme.of(context).dividerColor)),
          ),
          child: Row(
            children: [
              Container(
                width: 26,
                height: 26,
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [MyTheme.idColor, MyTheme.accent],
                  ),
                ),
                child: Text(initials,
                    style: const TextStyle(
                        fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white)),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 12.5),
                ),
              ),
            ],
          ),
        ),
      );
    });
  }

  // ------------------------------------------------------------- content --

  Widget _content(BuildContext context) {
    switch (_section.value) {
      case SpbimSection.conectar:
        return _Conectar();
      case SpbimSection.dispositivos:
        return const AddressBook();
      case SpbimSection.recentes:
        return _EmConstrucao(
          icon: Icons.history_outlined,
          title: 'Recentes',
          detail:
              'A lista de sessões recentes ainda usa a tela de Conectar por baixo — uma vista dedicada vem numa próxima versão.',
        );
      case SpbimSection.transferencias:
        return _EmConstrucao(
          icon: Icons.folder_outlined,
          title: 'Transferências',
          detail:
              'Pra transferir arquivos, conecte numa máquina em "Conectar" e use o menu de opções ao lado do botão Conectar.',
        );
      case SpbimSection.ajuda:
        return _EmConstrucao(
          icon: Icons.help_outline,
          title: 'Ajuda',
          detail: 'Precisando de suporte, fale com o time de TI da SPBIM.',
        );
    }
  }
}

/// Tela "Conectar": ID/senha desta máquina em formato compacto + campo de conexão + a lista
/// de dispositivos de sempre (ConnectionPage já traz o campo de ID e a grade de peers).
class _Conectar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _SelfIdPill().paddingOnly(top: 14, left: 16, right: 16, bottom: 4),
        Expanded(
          child: Container(
            color: Theme.of(context).scaffoldBackgroundColor,
            child: const ConnectionPage(),
          ),
        ),
      ],
    );
  }
}

/// Pill compacta com o ID e a senha temporária desta máquina — substitui o painel largo que
/// antes ocupava a coluna inteira da esquerda.
class _SelfIdPill extends StatefulWidget {
  @override
  State<_SelfIdPill> createState() => _SelfIdPillState();
}

class _SelfIdPillState extends State<_SelfIdPill> {
  @override
  Widget build(BuildContext context) {
    final model = gFFI.serverModel;
    return Align(
      alignment: Alignment.centerRight,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          border: Border.all(color: Theme.of(context).dividerColor),
          borderRadius: BorderRadius.circular(9),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Seu ID', style: TextStyle(fontSize: 12, color: Theme.of(context).textTheme.bodySmall?.color)),
            const SizedBox(width: 8),
            ChangeNotifierProvider.value(
              value: model,
              child: Consumer<ServerModel>(
                builder: (context, m, __) => GestureDetector(
                  onDoubleTap: () {
                    Clipboard.setData(ClipboardData(text: m.serverId.text));
                    showToast(translate('Copied'));
                  },
                  child: Text(
                    m.serverId.text,
                    style: const TextStyle(fontFamily: 'monospace', fontWeight: FontWeight.w700, fontSize: 13),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Text('· senha', style: TextStyle(fontSize: 12, color: Theme.of(context).textTheme.bodySmall?.color)),
            const SizedBox(width: 8),
            ChangeNotifierProvider.value(
              value: model,
              child: Consumer<ServerModel>(
                builder: (context, m, __) => Text(
                  m.serverPasswd.text,
                  style: const TextStyle(fontFamily: 'monospace', fontWeight: FontWeight.w700, fontSize: 13),
                ),
              ),
            ),
            const SizedBox(width: 6),
            InkWell(
              onTap: () => bind.mainUpdateTemporaryPassword(),
              child: const Padding(
                padding: EdgeInsets.all(4),
                child: Icon(Icons.refresh, size: 15),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmConstrucao extends StatelessWidget {
  final IconData icon;
  final String title;
  final String detail;

  const _EmConstrucao({required this.icon, required this.title, required this.detail});

  @override
  Widget build(BuildContext context) {
    final muted = Theme.of(context).textTheme.bodySmall?.color;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 34, color: muted),
            const SizedBox(height: 12),
            Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Text(
              detail,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12.5, color: muted, height: 1.5),
            ),
          ],
        ),
      ),
    );
  }
}
